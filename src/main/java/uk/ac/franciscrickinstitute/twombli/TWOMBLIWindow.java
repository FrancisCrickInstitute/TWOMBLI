package uk.ac.franciscrickinstitute.twombli;

import javax.swing.*;
import javax.swing.text.NumberFormatter;
import java.awt.*;
import java.awt.event.ActionListener;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;
import java.awt.event.WindowEvent;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import ij.IJ;
import ij.ImagePlus;
import ij.gui.ImageCanvas;
import ij.gui.StackWindow;
import ij.process.ImageProcessor;
import org.scijava.command.CommandModule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// Logservice integration
public class TWOMBLIWindow extends StackWindow implements ProgressCancelListener {

    private static final double MAX_MAGNIFICATION = 32.0;
    private static final double MIN_MAGNIFICATION = 1/72.0;
    private static final Logger log = LoggerFactory.getLogger(TWOMBLIWindow.class);

    protected final JPanel sidePanel;

    private ImagePlus originalImage;
    final TWOMBLIConfigurator plugin;
    private final JFormattedTextField minimumLineWidthField;
    private final JFormattedTextField maximumLineWidthField;
    private final JCheckBox darklinesCheckbox;
    private final JFormattedTextField minimumBranchLengthField;
    private final JFormattedTextField minimumCurvatureWindowField;
    private final JFormattedTextField maximumCurvatureWindowField;
    private final JFormattedTextField curvatureStepSizeField;
    private final JFormattedTextField maximumDisplayHDMField;
    private final JFormattedTextField contrastSaturationField;
    private final JCheckBox gapAnalysisCheckbox;
    private final JFormattedTextField gapAnalysisDiameterField;
    private final JButton anamorfButton;
    private final JButton saveConfigButton;
    private final JButton loadConfigButton;
    private final JButton infoButton;
    private final JButton changePreviewButton;
    private final JTextArea selectedPreviewPathField;
    private final JButton resetViewButton;
    private final JButton selectOutputButton;
    private final JTextArea selectedOutputField;
    private final JButton runPreviewButton;
//    private final JButton revertPreview;
    private final JButton selectBatchButton;
    private JTextArea selectedBatchField;
    private final JButton runButton;

    // Preview image controls
    private JTextArea currentlySelectedLabel;
    private Checkbox originalRadioButton;
    private Checkbox hdmRadioButton;
    private ImagePlus hdmImage;
    private Checkbox fibreRadioButton;
    private ImagePlus fibreImage;
    private Checkbox micRadioButton;
    private ImagePlus micImage;

    private String outputDirectory;
    private String anamorfPropertiesFile;
    private String batchPath;

    // Processing
    private HashMap<String, Object> inputs = new HashMap<>();
    private LinkedList<ImagePlus> processQueue = new LinkedList<>();
    private List<CommandModule> finishedFutures = new ArrayList<>();
    private int progressBarCurrent;
    private int progressBarMax;;
    private ProgressDialog customProgressBar;

    /*
    TODO: UX:
    - Think about previewing each step?
     */

    public TWOMBLIWindow(TWOMBLIConfigurator plugin, ImagePlus previewImage, ImagePlus originalImage) {
        super(previewImage, new ImageCanvas(previewImage));
        this.plugin = plugin;
        this.originalImage = originalImage;
        this.zoomImage();
        this.setTitle("TWOMBLI");

        // Layouts
        FlowLayout panelLayout = new FlowLayout();
        panelLayout.setAlignment(FlowLayout.LEFT);

        // Info button
        this.infoButton = new JButton("Information!");
        this.infoButton.setToolTipText("Get information about TWOMBLI.");
        ActionListener infoListener = e -> this.showInfo();
        this.infoButton.addActionListener(infoListener);

        // Change preview button
        this.changePreviewButton = new JButton("Change Preview Image");
        this.changePreviewButton.setToolTipText("Change the preview image to a different image.");
        ActionListener changePreviewListener = e -> this.changePreviewImage();
        this.changePreviewButton.addActionListener(changePreviewListener);

        // Current preview path
        this.selectedPreviewPathField = this.createWrappedLabel(this.originalImage.getOriginalFileInfo().getFilePath());

        // Reset View button
        this.resetViewButton = new JButton("Reset View");
        this.resetViewButton.setToolTipText("Reset the view to the original image.");
        ActionListener resetViewListener = e -> this.resetView();
        this.resetViewButton.addActionListener(resetViewListener);

        // Select output directory button
        this.selectOutputButton = new JButton("Select Output Directory (Required!)");
        this.selectOutputButton.setToolTipText("Choose a directory to output all the data. This includes preview data!");
        ActionListener selectOutputListener = e -> this.getOutputDirectory();
        this.selectOutputButton.addActionListener(selectOutputListener);
        this.selectedOutputField = this.createWrappedLabel("No output directory selected.");

        // Minimum line width panel
        JLabel minimLineWidthInfo = new JLabel("Minimum Line Width (px):");
        NumberFormat intFormat = NumberFormat.getIntegerInstance();
        NumberFormatter intFormatter = new NumberFormatter(intFormat);
        intFormatter.setValueClass(Integer.class);
        intFormatter.setMinimum(1);
        intFormatter.setMaximum(100);
        intFormatter.setAllowsInvalid(false);
        this.minimumLineWidthField = new JFormattedTextField(intFormat);
        this.minimumLineWidthField.setValue(5);
        JPanel minimumLineWidthPanel = new JPanel();
        minimumLineWidthPanel.setLayout(panelLayout);
        minimumLineWidthPanel.setToolTipText("Minimum line width in pixels. This should approximate the size of the smallest matrix fibres.");
        minimumLineWidthPanel.add(minimLineWidthInfo);
        minimumLineWidthPanel.add(this.minimumLineWidthField);

        // Maximum line width panel
        JLabel maximumLineWidthInfo = new JLabel("Maximum Line Width (px):");
        this.maximumLineWidthField = new JFormattedTextField(intFormat);
        this.maximumLineWidthField.setValue(5);
        JPanel maximumLineWidthPanel = new JPanel();
        maximumLineWidthPanel.setLayout(panelLayout);
        maximumLineWidthPanel.setToolTipText("Maximum line width in pixels. This should approximate the size of the largest matrix fibres.");
        maximumLineWidthPanel.add(maximumLineWidthInfo);
        maximumLineWidthPanel.add(this.maximumLineWidthField);

        // Darklines checkbox
        this.darklinesCheckbox = new JCheckBox("Dark Lines");
        this.darklinesCheckbox.setToolTipText("Check this box if the lines are darker as opposed to light.");

        // Minimum branch length
        JLabel minimumBranchLengthInfo = new JLabel("Minimum Branch Length (px):");
        this.minimumBranchLengthField = new JFormattedTextField(intFormat);
        this.minimumBranchLengthField.setValue(10);
        JPanel minimumBranchLengthPanel = new JPanel();
        minimumBranchLengthPanel.setLayout(panelLayout);
        minimumBranchLengthPanel.setToolTipText("The minimum length in pixels before a branch can occur.");
        minimumBranchLengthPanel.add(minimumBranchLengthInfo);
        minimumBranchLengthPanel.add(this.minimumBranchLengthField);

        // Minimum curvature
        JLabel minimumCurvatureWindowInfo = new JLabel("Minimum Anamorf Curvature Window:");
        this.minimumCurvatureWindowField = new JFormattedTextField(intFormat);
        this.minimumCurvatureWindowField.setValue(20);
        JPanel minimumCurvatureWindowPanel = new JPanel();
        minimumCurvatureWindowPanel.setLayout(panelLayout);
        minimumCurvatureWindowPanel.setToolTipText("The minimum curvature window for Anamorf.");
        minimumCurvatureWindowPanel.add(minimumCurvatureWindowInfo);
        minimumCurvatureWindowPanel.add(this.minimumCurvatureWindowField);

        // Maximum curvature
        JLabel maximumCurvatureWindowInfo = new JLabel("Maximum Anamorf Curvature Window:");
        this.maximumCurvatureWindowField = new JFormattedTextField(intFormat);
        this.maximumCurvatureWindowField.setValue(40);
        JPanel maximumCurvatureWindowPanel = new JPanel();
        maximumCurvatureWindowPanel.setLayout(panelLayout);
        maximumCurvatureWindowPanel.setToolTipText("The minimum curvature window for Anamorf.");
        maximumCurvatureWindowPanel.add(maximumCurvatureWindowInfo);
        maximumCurvatureWindowPanel.add(this.maximumCurvatureWindowField);

        // Maximum display HDM
        JLabel maximumDisplayHDMInfo = new JLabel("Maximum Display HDM:");
        this.maximumDisplayHDMField = new JFormattedTextField(intFormat);
        this.maximumDisplayHDMField.setValue(40);
        JPanel maximumDisplayHDMPanel = new JPanel();
        maximumDisplayHDMPanel.setLayout(panelLayout);
        maximumDisplayHDMPanel.setToolTipText("The maximum display HDM.");
        maximumDisplayHDMPanel.add(maximumDisplayHDMInfo);
        maximumDisplayHDMPanel.add(this.maximumDisplayHDMField);

        // Curvature step size
        JLabel curvatureStepSizeInfo = new JLabel("Curvature Step Size:");
        this.curvatureStepSizeField = new JFormattedTextField(intFormat);
        this.curvatureStepSizeField.setValue(10);
        JPanel curvatureStepSizePanel = new JPanel();
        curvatureStepSizePanel.setLayout(panelLayout);
        curvatureStepSizePanel.setToolTipText("The step size for the curvature window.");
        curvatureStepSizePanel.add(curvatureStepSizeInfo);
        curvatureStepSizePanel.add(this.curvatureStepSizeField);

        // Contrast Saturation
        JLabel contrastSaturationInfo = new JLabel("Contrast Saturation:");
        NumberFormat longFormat = NumberFormat.getNumberInstance();
        NumberFormatter longFormatter = new NumberFormatter(longFormat);
        intFormatter.setValueClass(Float.class);
        intFormatter.setMinimum(0.0);
        intFormatter.setMaximum(1.0);
        intFormatter.setAllowsInvalid(false);
        this.contrastSaturationField = new JFormattedTextField(longFormatter);
        this.contrastSaturationField.setValue(0.35);
        JPanel contrastSaturationPanel = new JPanel();
        contrastSaturationPanel.setLayout(panelLayout);
        contrastSaturationPanel.setToolTipText("The contrast saturation. (Between 0 and 1)");
        contrastSaturationPanel.add(contrastSaturationInfo);
        contrastSaturationPanel.add(this.contrastSaturationField);

        // Gap analysis checkbox
        this.gapAnalysisCheckbox = new JCheckBox("Perform Gap Analysis");
        this.gapAnalysisCheckbox.setToolTipText("Check this box to perform gap analysis.");
        this.gapAnalysisCheckbox.setSelected(true);

        // Gap analysis diameter
        JLabel gapAnalysisDiameterInfo = new JLabel("Minimum Gap Analysis Diameter:");
        this.gapAnalysisDiameterField = new JFormattedTextField(intFormat);
        this.gapAnalysisDiameterField.setValue(50);
        JPanel gapAnalysisDiameterPanel = new JPanel();
        gapAnalysisDiameterPanel.setLayout(panelLayout);
        gapAnalysisDiameterPanel.setToolTipText("The minimum diameter for gap analysis. 0 finds only 1.");
        gapAnalysisDiameterPanel.add(gapAnalysisDiameterInfo);
        gapAnalysisDiameterPanel.add(this.gapAnalysisDiameterField);

        // Anamorf properties
        this.anamorfButton = new JButton("Add Custom Anamorf Properties File (.xml)");
        this.anamorfButton.setToolTipText("Add a custom anamorf properties file to use for the analysis - if none provided, defaults will be used.");
        ActionListener anamorfListener = e -> this.getAnamorfProperties();
        this.anamorfButton.addActionListener(anamorfListener);

        // Save config button
        this.saveConfigButton = new JButton("Save Configuration");
        this.saveConfigButton.setToolTipText("Save the current TWOMBLI configuration to a file.");
        this.saveConfigButton.addActionListener(e -> this.saveConfiguration());

        // Load config button
        this.loadConfigButton = new JButton("Load Configuration");
        this.loadConfigButton.setToolTipText("Load the current TWOMBLI configuration to a file.");
        this.loadConfigButton.addActionListener(e -> this.loadConfiguration());

        // Run Preview button
        this.runPreviewButton = new JButton("Run Preview");
        this.runPreviewButton.setToolTipText("Run TWOMBLI with the current configuration on the preview image.");
        ActionListener runPreviewListener = e -> this.runPreviewProcess();
        this.runPreviewButton.addActionListener(runPreviewListener);

//        // Revert preview button
//        this.revertPreview = new JButton("Revert Preview");
//        this.revertPreview.setToolTipText("Revert the preview image to the original.");
//        ActionListener revertPreviewListener = e -> this.revertPreview();
//        this.revertPreview.addActionListener(revertPreviewListener);

        // Select batch button
        this.selectBatchButton = new JButton("Select Batch");
        this.selectBatchButton.setToolTipText("Choose a directory containing multiple images to run.");
        ActionListener selectBatchListener = e -> this.getBatchDirectory();
        this.selectBatchButton.addActionListener(selectBatchListener);
        this.selectedBatchField = this.createWrappedLabel("No batch directory selected.");

        // Run button
        this.runButton = new JButton("Run Batch");
        this.runButton.setToolTipText("Run TWOMBLI with the current configuration on the entire batch.");
        ActionListener runListener = e -> this.runProcess();
        this.runButton.addActionListener(runListener);

        // Configuration panel
        GridBagLayout configPanelLayout = new GridBagLayout();
        JPanel configPanel = new JPanel();
        configPanel.setBorder(BorderFactory.createTitledBorder("Configuration"));
        configPanel.setLayout(configPanelLayout);
        GridBagConstraints configPanelConstraints = new GridBagConstraints();
        configPanelConstraints.anchor = GridBagConstraints.NORTH;
        configPanelConstraints.fill = GridBagConstraints.HORIZONTAL;
        configPanelConstraints.gridwidth = 1;
        configPanelConstraints.gridheight = 1;
        configPanelConstraints.gridx = 0;
        configPanelConstraints.gridy = 0;
        configPanelConstraints.insets = new Insets(5, 5, 5, 5);

        // Minimum line width
        configPanel.add(minimumLineWidthPanel, configPanelConstraints);

        // Maximum line width
        configPanelConstraints.gridy++;
        configPanel.add(maximumLineWidthPanel, configPanelConstraints);

        // Darklines checkbox
        configPanelConstraints.gridy++;
        configPanel.add(this.darklinesCheckbox, configPanelConstraints);

        // Minimum branch length
        configPanelConstraints.gridy++;
        configPanel.add(minimumBranchLengthPanel, configPanelConstraints);

        // Minimum curvature window
        configPanelConstraints.gridy++;
        configPanel.add(minimumCurvatureWindowPanel, configPanelConstraints);

        // Maximum curvature window
        configPanelConstraints.gridy++;
        configPanel.add(maximumCurvatureWindowPanel, configPanelConstraints);

        // Curvature step size
        configPanelConstraints.gridy++;
        configPanel.add(curvatureStepSizePanel, configPanelConstraints);

        // Anamorf properties
        configPanelConstraints.gridy++;
        configPanel.add(this.anamorfButton, configPanelConstraints);

        // Maximum display HDM
        configPanelConstraints.gridy++;
        configPanel.add(maximumDisplayHDMPanel, configPanelConstraints);

        // Contrast saturation
        configPanelConstraints.gridy++;
        configPanel.add(contrastSaturationPanel, configPanelConstraints);

        // Gap analysis checkbox
        configPanelConstraints.gridy++;
        configPanel.add(this.gapAnalysisCheckbox, configPanelConstraints);

        // Gap analysis diameter
        configPanelConstraints.gridy++;
        configPanel.add(gapAnalysisDiameterPanel, configPanelConstraints);

        // Save config
        configPanelConstraints.gridy++;
        configPanel.add(this.saveConfigButton, configPanelConstraints);

        // Load Config
        configPanelConstraints.gridy++;
        configPanel.add(this.loadConfigButton, configPanelConstraints);

        // Sidebar panel
        GridBagLayout sidePanelLayout = new GridBagLayout();
        this.sidePanel = new JPanel();
        this.sidePanel.setLayout(sidePanelLayout);
        GridBagConstraints sidePanelConstraints = new GridBagConstraints();
        sidePanelConstraints.anchor = GridBagConstraints.NORTH;
        sidePanelConstraints.fill = GridBagConstraints.HORIZONTAL;
        sidePanelConstraints.gridwidth = 1;
        sidePanelConstraints.gridheight = 1;
        sidePanelConstraints.gridx = 0;
        sidePanelConstraints.gridy = 0;
        sidePanelConstraints.insets = new Insets(5, 5, 5, 5);

        // Help button
        this.sidePanel.add(this.infoButton, sidePanelConstraints);

        // Change preview button
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.changePreviewButton, sidePanelConstraints);

        // Preview path
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.selectedPreviewPathField, sidePanelConstraints);

        // Select Output Directory
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.selectOutputButton, sidePanelConstraints);

        // Output directory
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.selectedOutputField, sidePanelConstraints);

        // Configuration panel
        sidePanelConstraints.gridy++;
        this.sidePanel.add(configPanel, sidePanelConstraints);

        // Insert run preview button
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.runPreviewButton, sidePanelConstraints);

        // Configuration panel
        GridBagLayout previewPanelLayout = new GridBagLayout();
        JPanel previewPanel = new JPanel();
        previewPanel.setBorder(BorderFactory.createTitledBorder("Preview Images"));
        previewPanel.setLayout(previewPanelLayout);
        GridBagConstraints previewPanelConstraints = new GridBagConstraints();
        previewPanelConstraints.anchor = GridBagConstraints.NORTH;
        previewPanelConstraints.fill = GridBagConstraints.HORIZONTAL;
        previewPanelConstraints.gridwidth = 1;
        previewPanelConstraints.gridheight = 1;
        previewPanelConstraints.gridx = 0;
        previewPanelConstraints.gridy = 0;
        previewPanelConstraints.insets = new Insets(5, 5, 5, 5);

        // Selected info
        this.currentlySelectedLabel = this.createWrappedLabel("Currently Selected: None");

        // Button group
        CheckboxGroup radioGroup = new CheckboxGroup();

        // Original Image
        this.originalRadioButton = new Checkbox("Original Image", radioGroup, false);
        this.originalRadioButton.addItemListener(e -> this.handleOriginalButtonPressed());
        this.originalRadioButton.setEnabled(false);
        previewPanelConstraints.gridy++;
        previewPanel.add(this.originalRadioButton, previewPanelConstraints);

        // HDM Image
        this.hdmRadioButton = new Checkbox("HDM Image", radioGroup, false);
        this.hdmRadioButton.addItemListener(e -> this.handleHDMButtonPressed());
        this.hdmRadioButton.setEnabled(false);
        previewPanelConstraints.gridy++;
        previewPanel.add(this.hdmRadioButton, previewPanelConstraints);

        // Fibre Overlay
        this.fibreRadioButton = new Checkbox("Fibre Overlay", radioGroup, false);
        this.fibreRadioButton.addItemListener(e -> this.handleFibreButtonPressed());
        this.fibreRadioButton.setEnabled(false);
        previewPanelConstraints.gridy++;
        previewPanel.add(this.fibreRadioButton, previewPanelConstraints);

        // MIC
        this.micRadioButton = new Checkbox("Gap Analysis", radioGroup, false);
        this.micRadioButton.addItemListener(e -> this.handleMICButtonPressed());
        this.micRadioButton.setEnabled(false);
        previewPanelConstraints.gridy++;
        previewPanel.add(this.micRadioButton, previewPanelConstraints);

        // Preview panel
        sidePanelConstraints.gridy++;
        this.sidePanel.add(previewPanel, sidePanelConstraints);

//        // Revert preview button
//        sidePanelConstraints.gridy++;
//        sidePanel.add(this.revertPreview, sidePanelConstraints);

        // Select Batch
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.selectBatchButton, sidePanelConstraints);

        // Batch directory
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.selectedBatchField, sidePanelConstraints);

        // Insert run button
        sidePanelConstraints.gridy++;
        this.sidePanel.add(this.runButton, sidePanelConstraints);

        // Spacer so we valign
        sidePanelConstraints.gridy++;
        sidePanelConstraints.weighty = 1;
        this.sidePanel.add(Box.createVerticalBox(), sidePanelConstraints);

        // X11 RD Dimensions
        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        int width = (int) (screenSize.width * 0.4);
        int height = (int) (screenSize.height * 0.6);

        // Scroll bar
        JScrollPane sidePanelScroll = new JScrollPane(this.sidePanel, ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS, ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
        sidePanelScroll.setMinimumSize(new Dimension(width / 4, height));
        sidePanelScroll.getViewport().setScrollMode(JViewport.BACKINGSTORE_SCROLL_MODE);

        // Content panel
        GridBagLayout contentPanelLayout = new GridBagLayout();
        Panel contentPanel = new Panel();
        contentPanel.setLayout(contentPanelLayout);
        GridBagConstraints contentPanelConstraints = new GridBagConstraints();
        contentPanelConstraints.anchor = GridBagConstraints.NORTHWEST;
        contentPanelConstraints.fill = GridBagConstraints.BOTH;
        contentPanelConstraints.gridwidth = 1;
        contentPanelConstraints.gridheight = 1;
        contentPanelConstraints.gridx = 0;
        contentPanelConstraints.gridy = 0;
        contentPanelConstraints.weightx = 0.5;
        contentPanelConstraints.weighty = 1;

        // Image display
        final ImageCanvas canvas = this.getCanvas();

        // Insert canvas first
        contentPanel.add(canvas, contentPanelConstraints);

        // Side panel for controls
        contentPanelConstraints.gridx++;
        contentPanelConstraints.weightx = 0.3;
        contentPanelConstraints.weighty = 1;
        contentPanel.add(sidePanelScroll, contentPanelConstraints);

        // Core window layout properties
        GridBagLayout windowLayout = new GridBagLayout();
        GridBagConstraints windowConstraints = new GridBagConstraints();
        windowConstraints.anchor = GridBagConstraints.NORTHWEST;
        windowConstraints.fill = GridBagConstraints.BOTH;
        windowConstraints.weightx = 1;
        windowConstraints.weighty = 1;
        this.setLayout(windowLayout);
        this.add(contentPanel, windowConstraints);

        // Disable all interactions until we have an output directory
        this.toggleOutputAvailableInteractions(false);

        // Finish up and set our sizes
        RepaintManager.currentManager(this).setDoubleBufferingEnabled(true);
        this.pack();
        this.addComponentListener(new ComponentAdapter() {
            @Override
            public void componentResized(ComponentEvent e) {
                SwingUtilities.invokeLater(() -> {
                    super.componentResized(e);
                    canvas.fitToWindow();
                    sidePanel.revalidate();
                    sidePanel.repaint();
                });
            }
        });
    }

    private void handleOriginalButtonPressed() {
        this.currentlySelectedLabel.setText("Currently Selected: Original Image");
        ImagePlus preview;
        if (this.originalImage.getImageStackSize() == 1) {
            preview = ImageUtils.duplicateImage(this.originalImage);
        }

        // Only take the 'currently selected' file for our preview.
        else {
            preview = this.originalImage.crop();
        }

        this.setImage(preview);
    }

    private void handleHDMButtonPressed() {
        this.currentlySelectedLabel.setText("Currently Selected: HDM Image");
        ImagePlus preview;
        if (this.hdmImage.getImageStackSize() == 1) {
            preview = ImageUtils.duplicateImage(this.hdmImage);
        }
        else {
            preview = this.hdmImage.crop();
        }
        this.setImage(preview);
    }

    private void handleFibreButtonPressed() {
        this.currentlySelectedLabel.setText("Currently Selected: Fibre Overlay");
        ImagePlus base;
        if (this.originalImage.getImageStackSize() == 1) {
            base = ImageUtils.duplicateImage(this.originalImage);
        }
        else {
            base = this.originalImage.crop();
        }

        ImagePlus overlay;
        if (this.fibreImage.getImageStackSize() == 1) {
            overlay = ImageUtils.duplicateImage(this.fibreImage);
        }
        else {
            overlay = this.fibreImage.crop();
        }

        // Get the image processors
        ImageProcessor baseProcessor = base.getProcessor();
        ImageProcessor overlayProcessor = overlay.getProcessor();

        // Overlay the images
        for (int y = 0; y < base.getHeight(); y++) {
            for (int x = 0; x < base.getWidth(); x++) {
                int maskPixel = overlayProcessor.get(x, y);
                if (maskPixel != 0) {
                    continue;
                }

                baseProcessor.putPixel(x, y, 16711935);
            }
        }

        base.updateAndDraw();
        this.setImage(base);
    }

    private void handleMICButtonPressed() {
        this.currentlySelectedLabel.setText("Currently Selected: MIC Overlay");
        ImagePlus preview;
        if (this.micImage.getImageStackSize() == 1) {
            preview = ImageUtils.duplicateImage(this.micImage);
        }
        else {
            preview = this.micImage.crop();
        }
        this.setImage(preview);
    }

    @Override
    public void windowClosing(WindowEvent e) {
        super.windowClosing(e);
    }

    private void toggleOutputAvailableInteractions(boolean state) {
        this.minimumLineWidthField.setEnabled(state);
        this.maximumLineWidthField.setEnabled(state);
        this.darklinesCheckbox.setEnabled(state);
        this.minimumBranchLengthField.setEnabled(state);
        this.minimumCurvatureWindowField.setEnabled(state);
        this.maximumCurvatureWindowField.setEnabled(state);
        this.maximumDisplayHDMField.setEnabled(state);
        this.curvatureStepSizeField.setEnabled(state);
        this.contrastSaturationField.setEnabled(state);
        this.gapAnalysisCheckbox.setEnabled(state);
        this.gapAnalysisDiameterField.setEnabled(state);
        this.anamorfButton.setEnabled(state);
        this.runPreviewButton.setEnabled(state);
//        this.revertPreview.setEnabled(state);
        this.selectBatchButton.setEnabled(state);
        this.toggleRunButton(state);
    }

    private void toggleRunButton(boolean state) {
        if (!state) {
            this.runButton.setEnabled(false);
            return;
        }

        if (this.batchPath == null) {
            this.runButton.setEnabled(false);
            return;
        }

        this.runButton.setEnabled(true);
    }

    private void zoomImage() {
        // Adjust our screen positions + image sizes
        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        double width = screenSize.getWidth();
        double height = screenSize.getHeight();

        // Zoom in if our image is small
        while ((this.ic.getWidth() < width / 2 || this.ic.getHeight() < height / 2)
                && this.ic.getMagnification() < TWOMBLIWindow.MAX_MAGNIFICATION) {
            final int canvasWidth = this.ic.getWidth();
            this.ic.zoomIn(0, 0);
            if (canvasWidth == this.ic.getWidth()) {
                this.ic.zoomOut(0, 0);
                break;
            }
        }

        // Zoom out if our image is large
        while ((this.ic.getWidth() > 0.75 * width || this.ic.getHeight() > 0.75 * height)
                && this.ic.getMagnification() > TWOMBLIWindow.MIN_MAGNIFICATION) {
            final int canvasWidth = this.ic.getWidth();
            this.ic.zoomOut(0, 0);
            if (canvasWidth == this.ic.getWidth()) {
                this.ic.zoomIn(0, 0);
                break;
            }
        }
    }

    private void showInfo() {
        String info = "TWOMBLI is a tool for the analysis of matrix fibres in images.\n" +
                "It is designed to be used with images of the extracellular matrix.\n" +
                "For more information, please see: {TODO:paper_linl}\n" +
                "For a video on how to use TWOMBLI, please visit: {TODO:video_link}\n" +
                "Please report any issues to: {TODO:github_link}\n" +
                "TWOMBLI utilises various third party tools and libraries, including:\n" +
                " - OrientationJ: {TODO:orientation_link}\n" +
                " - Anamorf: {TODO:anamorf_link}\n" +
                " - IJ-RidgeDetection: {TODO:ij_ridge_link}\n" +
                " - MaxInscribedCircles: {TODO:circles_link}\n" +
                " - Bio-Formats: {TODO:bioformats_link}\n";
        IJ.showMessage(info);
    }

    private void changePreviewImage() {
        ImagePlus newPreview = IJ.openImage();
        if (newPreview == null) {
            return;
        }

        this.setImage(newPreview);
        this.originalImage = newPreview;
        this.selectedPreviewPathField.setText(newPreview.getOriginalFileInfo().getFilePath());
    }

    private void resetView() {
        this.setImage(this.originalImage);
        this.zoomImage();
    }

    private void getOutputDirectory() {
        String potential = IJ.getDirectory("Get output directory");
        if (!Files.isDirectory(Paths.get(potential))) {
            this.toggleOutputAvailableInteractions(false);
            return;
        }

        // Ensure the directory is empty
        boolean outcome = FileUtils.verifyOutputDirectoryIsEmpty(potential);
        if (!outcome) {
            return;
        }

        // Set the other actions as enabled
        this.outputDirectory = potential;
        this.selectedOutputField.setText(potential);
        this.toggleOutputAvailableInteractions(true);
    }

    private void getAnamorfProperties() {
        String potential = IJ.getFilePath("Get anamorf properties");
        if (potential == null) {
            this.anamorfPropertiesFile = potential;
            return;
        }

        if (!Files.isRegularFile(Paths.get(potential)) && !potential.endsWith(".xml")) {
            return;
        }

        // Set the other actions as enabled
        this.anamorfPropertiesFile = potential;
    }

    private void saveConfiguration() {
        String potentialSavePath = IJ.getDirectory("Save TWOMBLI Configuration");
        if (potentialSavePath == null || !Files.isDirectory(Paths.get(potentialSavePath))) {
            return;
        }

        Path savePath = Paths.get(potentialSavePath, "twombli_configuraiton.txt");
        try (BufferedWriter configWriter = Files.newBufferedWriter(savePath, StandardOpenOption.CREATE_NEW)) {
            configWriter.write("MINIMUM_LINE_WIDTH:" + Integer.valueOf(this.minimumLineWidthField.getText()) + "\n");
            configWriter.write("MAXIMUM_LINE_WIDTH:" + Integer.valueOf(this.maximumLineWidthField.getText()) + "\n");
            configWriter.write("DARK_LINES:" + this.darklinesCheckbox.isSelected() + "\n");
            configWriter.write("MINIMUM_BRANCH_LENGTH:" + Integer.valueOf(this.minimumBranchLengthField.getText()) + "\n");
            configWriter.write("MINIMUM_CURVATURE_WINDOW:" + Integer.valueOf(this.minimumCurvatureWindowField.getText()) + "\n");
            configWriter.write("MAXIMUM_CURVATURE_WINDOW:" + Integer.valueOf(this.maximumCurvatureWindowField.getText()) + "\n");
            configWriter.write("CURVATURE_WINDOW_STEP_SIZE:" + Integer.valueOf(this.curvatureStepSizeField.getText()) + "\n");
            configWriter.write("MAXIMUM_DISPLAY_HDM:" + Integer.valueOf(this.maximumDisplayHDMField.getText()) + "\n");
            configWriter.write("CONTRAST_SATURATION:" + Float.valueOf(this.contrastSaturationField.getText()) + "\n");
            configWriter.write("PERFORM_GAP_ANALYSIS:" + this.gapAnalysisCheckbox.isSelected() + "\n");
            configWriter.write("MINIMUM_GAP_DIAMETER:" + Integer.valueOf(this.gapAnalysisDiameterField.getText()) + "\n");

            if (this.anamorfPropertiesFile != null) {
                configWriter.write("ANAMORF_FILE:" + this.anamorfPropertiesFile + "\n");
            }
        }

        catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void loadConfiguration() {
        String potentialSaveFile = IJ.getFilePath("Load TWOMBLI Configuration");
        if (potentialSaveFile == null) {
            return;
        }

        Path savePath = Paths.get(potentialSaveFile);
        if (!Files.isRegularFile(savePath)) {
            return;
        }

        try (BufferedReader configReader = Files.newBufferedReader(savePath)) {
            String line;
            while ((line = configReader.readLine()) != null) {
                String[] config = line.split(":");

                if (config.length != 2) {
                    continue; // Skip invalid lines
                }

                String key = config[0];
                String value = config[1];

                switch (key) {
                    case "MINIMUM_LINE_WIDTH":
                        this.minimumLineWidthField.setText(value);
                        break;
                    case "MAXIMUM_LINE_WIDTH":
                        this.maximumLineWidthField.setText(value);
                        break;
                    case "DARK_LINES":
                        this.darklinesCheckbox.setSelected(Boolean.parseBoolean(value));
                        break;
                    case "MINIMUM_BRANCH_LENGTH":
                        this.minimumBranchLengthField.setText(value);
                        break;
                    case "MINIMUM_CURVATURE_WINDOW":
                        this.minimumCurvatureWindowField.setText(value);
                        break;
                    case "MAXIMUM_CURVATURE_WINDOW":
                        this.maximumCurvatureWindowField.setText(value);
                        break;
                    case "CURVATURE_WINDOW_STEP_SIZE":
                        this.curvatureStepSizeField.setText(value);
                        break;
                    case "MAXIMUM_DISPLAY_HDM":
                        this.maximumDisplayHDMField.setText(value);
                        break;
                    case "CONTRAST_SATURATION":
                        this.contrastSaturationField.setText(value);
                        break;
                    case "PERFORM_GAP_ANALYSIS":
                        this.gapAnalysisCheckbox.setSelected(Boolean.parseBoolean(value));
                        break;
                    case "MINIMUM_GAP_DIAMETER":
                        this.gapAnalysisDiameterField.setText(value);
                        break;
                    case "ANAMORF_FILE":
                        this.anamorfPropertiesFile = value;
                        break;
                    default:
                        // Unknown configuration key, can log or ignore
                        break;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void getBatchDirectory() {
       String potential = IJ.getDirectory("Get Batch Folder");
       if (potential == null) {
           this.batchPath = potential;
           return;
       }

        if (!Files.isDirectory(Paths.get(potential))) {
            return;
        }

        // Set the other actions as enabled
        this.batchPath = potential;
        this.selectedBatchField.setText(potential);
        this.toggleRunButton(true);
    }

    private HashMap<String, Object> getInputs() {
        HashMap<String, Object> inputs = new HashMap<>();
        inputs.put("outputPath", this.outputDirectory);
        inputs.put("minimumLineWidth", Integer.valueOf(this.minimumLineWidthField.getText()));
        inputs.put("maximumLineWidth", Integer.valueOf(this.maximumLineWidthField.getText()));
        inputs.put("darkLines", this.darklinesCheckbox.isSelected());
        inputs.put("minimumBranchLength", Integer.valueOf(this.minimumBranchLengthField.getText()));

        Integer minValue = Integer.valueOf(this.minimumCurvatureWindowField.getText());
        Integer maxValue = Integer.valueOf(this.maximumCurvatureWindowField.getText());
        if (maxValue < minValue) {
            maxValue = minValue;
        }
        inputs.put("minimumCurvatureWindow", minValue);
        inputs.put("maximumCurvatureWindow", maxValue);

        inputs.put("curvatureWindowStepSize", Integer.valueOf(this.curvatureStepSizeField.getText()));
        inputs.put("maximumDisplayHDM", Integer.valueOf(this.maximumDisplayHDMField.getText()));
        inputs.put("contrastSaturation", Float.valueOf(this.contrastSaturationField.getText()));
        inputs.put("performGapAnalysis", this.gapAnalysisCheckbox.isSelected());
        inputs.put("minimumGapDiameter", Integer.valueOf(this.gapAnalysisDiameterField.getText()));

        if (this.anamorfPropertiesFile != null) {
            inputs.put("anamorfPropertiesFile", this.anamorfPropertiesFile);
        }

        return inputs;
    }

    private void runPreviewProcess() {
        this.preparePreview();
        this.startProcessing(true);
    }

    private void preparePreview() {
        // Just copy
        ImagePlus preview;
        if (this.originalImage.getImageStackSize() == 1) {
            preview = ImageUtils.duplicateImage(this.originalImage);
        }

        // Only take the 'currently selected' file for our preview.
        else {
            preview = this.originalImage.crop();
        }


        // Run command and poll for our outputs
        this.processQueue.add(preview);
    }

    private void revertPreview() {
        // Just copy
        ImagePlus preview;
        if (this.originalImage.getImageStackSize() == 1) {
            preview = ImageUtils.duplicateImage(this.originalImage);
        }

        // Only take the 'currently selected' file for our preview.
        else {
            preview = this.originalImage.crop();
        }

        this.setImage(preview);
    }

    private void runProcess() {
//        this.preparePreview();

        // Skip if we don't have a batch path
        if (this.batchPath == null) {
            return;
        }

        // Identify our batch targets
        File sourceDirectory = new File(this.batchPath);
        File[] files = sourceDirectory.listFiles((dir, name) -> {
            for (String suffix : TWOMBLIConfigurator.EXTENSIONS) {
                if (name.endsWith(suffix)) {
                    return true;
                }
            }

            return false;
        });

        // Loop through our files, load their images, add to queue
        assert files != null;
        for (File file : files) {
            ImagePlus img = IJ.openImage(file.getAbsolutePath());
            this.processQueue.add(img);
        }

        this.startProcessing(false);
    }

    private void startProcessing(boolean hasPreview) {
        this.inputs = this.getInputs();

        // Empty our output directory (which should only contain previous run data)
        boolean outcome = FileUtils.verifyOutputDirectoryIsEmpty(this.outputDirectory);
        if (!outcome) {
            this.processQueue.clear();
            return;
        }

        // Prepare a progress bar and block user input
        this.progressBarCurrent = 0;
        this.progressBarMax = this.processQueue.size();
        IJ.showMessage("Processing Images. This may take a while. (Press OK to start.)");
        IJ.showProgress(this.progressBarCurrent, this.progressBarMax);
        this.customProgressBar = new ProgressDialog(IJ.getInstance(), "Processing Images", this.progressBarMax, this);

        // Process our first image
        this.processNext(hasPreview);
    }

    private void processNext(boolean isPreview) {
        if (this.processQueue.isEmpty()) {
            return;
        }

        ImagePlus img = this.processQueue.remove();
        this.inputs.put("img", img);
        Future<CommandModule> future = this.plugin.commandService.run(TWOMBLIRunner.class, false, inputs);

//        // Delay our polling to prevent weird race conditions
//        try {
//            Thread.sleep(1000);
//        } catch (InterruptedException e) {
//            e.printStackTrace();
//        }
//        this.plugin.moduleService.waitFor(future);

        Thread t = new Thread(new FuturePoller(this, future, isPreview));
        t.start();
    }

    public void handleFutureComplete(Future<CommandModule> future, boolean isPreview) {
        try {
            // Update our preview image with our output
            if (isPreview) {
                CommandModule output = future.get();
                this.originalRadioButton.setEnabled(true);
                this.hdmRadioButton.setEnabled(true);
                this.hdmImage = (ImagePlus) output.getOutput("hdmImage");
                this.fibreRadioButton.setEnabled(true);
                this.fibreImage = (ImagePlus) output.getOutput("maskImage");
                this.micRadioButton.setEnabled(true);
                this.micImage = (ImagePlus) output.getOutput("gapImage");
                this.fibreRadioButton.setState(true);
                this.handleFibreButtonPressed();
            }

            // Store our output for collation
            else {
                CommandModule output = future.get();
                this.finishedFutures.add(output);
            }

        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }

        // Check if we have more to process.
        if (this.progressBarCurrent + 1 != this.progressBarMax) {
            this.progressBarCurrent += 1;
            IJ.showProgress(this.progressBarCurrent, this.progressBarMax);
            this.customProgressBar.updateProgress(this.progressBarCurrent);
            this.processNext(false);
        }

        // Restore our gui functionality & close progress bars
        else {
            IJ.showProgress(1, 1);
            this.customProgressBar.dispose();
            this.generateSummaries();
        }
    }

    private void generateSummaries() {
        // Loop through our results and generate a summary
        Path gapsOutputPath = Paths.get(this.outputDirectory, "gaps_summary.csv");
        Path twombliOutputPath = Paths.get(this.outputDirectory, "twombli_summary.csv");
        Path successLog = Paths.get(this.outputDirectory, "success.log");
        boolean doHeader = true;

        try (BufferedWriter successWriter = Files.newBufferedWriter(successLog, StandardOpenOption.CREATE_NEW)) {
            for (CommandModule output : this.finishedFutures) {
                // Gather our basic info
                String filePrefix = (String) output.getInput("filePrefix");
                boolean success = (boolean) output.getOutput("complete");
                double alignment = (double) output.getOutput("alignment");
                int dimension = (int) output.getOutput("dimension");
                Path anamorfSummaryPath = Paths.get(this.outputDirectory, "masks", filePrefix + "_results.csv");
                Path hdmSummaryPath = Paths.get(this.outputDirectory, "hdm_csvs", filePrefix + "_ResultsHDM.csv");
                Path gapAnalysisPath = Paths.get(this.outputDirectory, "gap_analysis", filePrefix + "_gaps.csv");
                Outputs.generateSummaries(twombliOutputPath, alignment, dimension, anamorfSummaryPath, hdmSummaryPath, gapAnalysisPath, doHeader, this.gapAnalysisCheckbox.isSelected(), gapsOutputPath);
                doHeader = false;
                successWriter.write(filePrefix + ": " + success + "\n");
            }
        }

        catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void handleProgressBarCancelled() {
        this.processQueue.clear();
    }

    private JTextArea createWrappedLabel(String text) {
        JTextArea label = new JTextArea(text);
        label.setEditable(false);
        label.setWrapStyleWord(true);
        label.setLineWrap(true);
        label.setOpaque(false);
        label.setFocusable(false);
        label.setFont(new JLabel().getFont());
        label.setBorder(null);
        return label;
    }
}

package uk.ac.franciscrickinstitute;

import javax.swing.*;

import java.util.ArrayList;
import java.util.Arrays;

import ij.IJ;
import ij.ImagePlus;
import ij.ImageStack;
import ij.WindowManager;
import org.scijava.app.StatusService;
import org.scijava.command.Command;
import org.scijava.command.CommandService;
import org.scijava.module.ModuleService;
import org.scijava.plugin.Parameter;
import org.scijava.plugin.Plugin;

@Plugin(type = Command.class, headless = true, menuPath = "TWOMBLI>Configurator")
public class TWOMBLIConfigurator implements Command {

    public static final ArrayList<String> EXTENSIONS = new ArrayList<>(Arrays.asList(
            "png",
            "tif",
            "tiff"
    ));

    @Parameter
    protected CommandService commandService;

    @Parameter
    protected StatusService statusService;

    @Parameter
    protected ModuleService moduleService;

    @Override
    public void run() {
        // TODO: Embed this image grabber into the window itself?

        // Grab our current image or 'invite' the user to open one!
        ImagePlus initialImage = WindowManager.getCurrentImage();
        if (initialImage == null) {
            // TODO: Inform the user?
            initialImage = IJ.openImage();
            if (initialImage == null) {
                return;
            }
        }

        // Make a copy for our own manipulation - don't affect the original
        ImagePlus dataImage = ImageUtils.duplicateImage(initialImage);
        dataImage.setTitle("TWOMBLI");

        // Make a copy of the current selected image for our preview
        ImagePlus displayImage = dataImage.crop();
        displayImage.setTitle("TWOMBLI Preview");

        // Display our GUI for this plugin
        SwingUtilities.invokeLater(
                () -> {
                    TWOMBLIWindow window = new TWOMBLIWindow(this, displayImage, dataImage);
                    window.pack();
                }
        );
    }
}

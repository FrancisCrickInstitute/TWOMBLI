package uk.ac.franciscrickinstitute.twombli;

import java.awt.*;
import java.awt.event.*;

import ij.gui.GUI;

public class ProgressDialog extends Dialog implements WindowListener {

    private final int maxProgress;
    private final ProgressCanvas progressCanvas;
    private final ProgressCancelListener progressCancelListener;

    public ProgressDialog(Frame parent, String title, int maxProgress, ProgressCancelListener listener) {
        super(parent, title, true);
        this.maxProgress = maxProgress;
        this.progressCancelListener = listener;

        this.setModal(false);

        // Create a canvas to draw the progress bar
        this.progressCanvas = new ProgressCanvas(this.maxProgress);
        this.progressCanvas.setSize(300, 30);

        // Set up the dialog layout
        setLayout(new BorderLayout());
        add(this.progressCanvas, BorderLayout.CENTER);

        // Create a cancel button
        Button cancelButton = new Button("Cancel");
        cancelButton.addActionListener(e -> this.handleProgressBarCancelled());
        add(cancelButton, BorderLayout.SOUTH);

        GUI.scale(this);
        pack();
        GUI.centerOnImageJScreen(this);
        this.setVisible(true);
    }

    // Method to update the progress bar
    public void updateProgress(int newProgress) {
        this.progressCanvas.setProgress(newProgress);
    }

    private void handleProgressBarCancelled() {
        this.progressCancelListener.handleProgressBarCancelled();
        this.dispose();
    }

    @Override
    public void windowOpened(WindowEvent e) {}

    @Override
    public void windowClosing(WindowEvent e) {}

    @Override
    public void windowClosed(WindowEvent e) {
        this.handleProgressBarCancelled();
    }

    @Override
    public void windowIconified(WindowEvent e) {}

    @Override
    public void windowDeiconified(WindowEvent e) {}

    @Override
    public void windowActivated(WindowEvent e) {}

    @Override
    public void windowDeactivated(WindowEvent e) {}

    // Canvas for drawing the progress bar
    private class ProgressCanvas extends Canvas {
        private final int maxProgress;
        private int currentProgress = 0;

        public ProgressCanvas(int maxProgress) {
            this.maxProgress = maxProgress;
            this.currentProgress = 0;
        }

        public void setProgress(int progress) {
            this.currentProgress = progress;
            repaint();
        }

        @Override
        public void paint(Graphics g) {
            // Clear the canvas
            g.setColor(Color.WHITE);
            g.fillRect(0, 0, getWidth(), getHeight());

            // Draw the progress bar background
            g.setColor(Color.GRAY);
            g.fillRect(0, 0, getWidth(), getHeight());

            // Draw the progress based on the current value
            g.setColor(Color.GREEN);
            int barWidth = (int) ((getWidth() * currentProgress) / (float) maxProgress);
            g.fillRect(0, 0, barWidth, getHeight());

            // Draw the progress percentage
            g.setColor(Color.BLACK);
            int percent = (int) ((currentProgress / (float) maxProgress) * 100);
            String progressText = percent + "%";
            g.drawString(progressText, getWidth() / 2 - g.getFontMetrics().stringWidth(progressText) / 2, getHeight() / 2 + 5);
        }
    }
}

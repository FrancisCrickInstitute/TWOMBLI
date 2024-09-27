package uk.ac.franciscrickinstitute.twombli;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Stream;

import ij.IJ;
import ij.gui.YesNoCancelDialog;

public class FileUtils {
    public static void deleteDirectoryContents(File sourceDirectory) {
        File[] files = sourceDirectory.listFiles();
        assert files != null;
        for (File file : files) {
            if (file.isDirectory()) {
                FileUtils.deleteDirectoryContents(file);
                file.delete();
            } else {
                file.delete();
            }
        }
    }

    public static boolean verifyOutputDirectoryIsEmpty(String potential) {
        // Output must be an empty directory
        boolean foundFiles = false;
        try (Stream<Path> entries = Files.list(Paths.get(potential))) {
            if (entries.findFirst().isPresent()) {
                foundFiles = true;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        // Return if there were no files present
        if (!foundFiles) {
            return true;
        }

        YesNoDialog dialog = new YesNoDialog(
                IJ.getInstance(),
                "Output Directory Not Empty",
                "The output directory is not empty and this is currently a requirement for the plugin. Would you like to continue and overwrite? If you are unsure, simply make a new directory when selecting your output directory!",
                "Delete Contents", "Cancel");
        if (!dialog.yesPressed()) {
            return false;
        }

        FileUtils.deleteDirectoryContents(new File(potential));
        return true;
    }
}

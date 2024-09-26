package uk.ac.franciscrickinstitute.twombli;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.List;

public class Outputs {

    public static void generateSummaries(Path twombli_csv_path, double alignment, int dimension, Path anamorfSummaryPath, Path hdmSummaryPath, Path gapAnalysisPath, boolean doHeader, boolean gapAnalysis, Path gap_csv_path) {
        // Write to our twombli summary
        try {
            List<String> lines = new ArrayList<>();
            List<String> anamorfEntries = Files.readAllLines(anamorfSummaryPath);
            List<String> hdmEntries = Files.readAllLines(hdmSummaryPath);

            // Conditionally write out our header
            if (doHeader) {
                String headerItems = anamorfEntries.get(0);
                String[] hdmHeaderItems = hdmEntries.get(0).split(",");
                String header = headerItems + "," + hdmHeaderItems[hdmHeaderItems.length - 1] + ",Alignment (Coherency [%]),Size";
                lines.add(header);
            }

            // Get the data
            String anamorfData = anamorfEntries.get(anamorfEntries.size() - 1);
            String[] hdmData = hdmEntries.get(hdmEntries.size() - 1).split(",");
            double hdmValue = 1 - Double.parseDouble(hdmData[hdmData.length - 1]);
            lines.add(anamorfData + "," + hdmValue + "," + alignment + "," + dimension);

            // Write
            Files.write(twombli_csv_path, lines, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        }

        catch (IOException e) {
            throw new RuntimeException(e);
        }

        // Write to our gap analysis summary
        if (gapAnalysis) {
            try (BufferedReader reader = Files.newBufferedReader(gapAnalysisPath);
                 BufferedWriter writer = Files.newBufferedWriter(gap_csv_path, StandardOpenOption.CREATE, StandardOpenOption.APPEND)) {

                String line;
                while ((line = reader.readLine()) != null) {
                    writer.write(line.replace(" ", ","));
                    writer.newLine(); // Ensure proper newline after each row
                }

            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
    }
}

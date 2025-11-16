package io.github.montanizstills.utils;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class Utils {
    public String getResourceAsStringFromFile(String fileName) {
        try (InputStream is = Utils.class.getClassLoader().getResourceAsStream(fileName)) {
            if (is == null) {
                System.err.println("Resource not found: " + fileName);
                return null;
            }
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new Error(e);
        }
    }
}

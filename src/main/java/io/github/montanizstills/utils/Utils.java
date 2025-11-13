package io.github.montanizstills.utils;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

public class Utils {
    public String getResourceAsStringFromFile(String fileName) {
        try (InputStream is = Utils.class.getClassLoader().getResourceAsStream(fileName)) {
            if (is == null) {
                System.err.println("Resource not found: " + fileName);
                return null;
            }
            String content = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            return content;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }

    public Map<String, String> createJsonMap(String fileName) throws JsonProcessingException {
        ObjectMapper objectMapper = new ObjectMapper();
        Map mapToReturn = objectMapper.readValue(getResourceAsStringFromFile(fileName), Map.class);
        return mapToReturn;
    }

}

package io.github.montanizstills.heygenAPI;

import com.fasterxml.jackson.core.JsonProcessingException;
import io.github.montanizstills.utils.Utils;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class HeygenUtils {

    private String heygen_api_key;

    public HeygenUtils() {
    }

    public void createAPIKey() {
        try {
            this.heygen_api_key = new Utils().createJsonMap("secrets.json").get("HEYGEN_API_KEY");
        } catch (JsonProcessingException e) {
            throw new Error(e);
        }
    }

    public void simpleGet(String URI_Input) throws IOException, InterruptedException {
        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(URI_Input))
                .header("x-api-key", heygen_api_key)
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        System.out.println("Response Status Code: " + response.statusCode());
        System.out.println("Response Body: " + response.body());
    }


}

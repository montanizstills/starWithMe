package http;

import io.github.montanizstills.heygenAPI.HeygenUtils;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public enum SimpleHttp {
    GET, POST, PUT, DELETE;

    public void sendRequest(String uriInput, String requestBody) {

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                .uri(URI.create(uriInput))
                .header("Content-Type", "application/json")
                .header("x-api-key", new HeygenUtils().getHeygen_api_key());

        switch (this.name()) {
            case "GET":
                requestBuilder.GET();
                break;
            case "POST":
                requestBuilder.POST(HttpRequest.BodyPublishers.ofString(
                        requestBody != null ? requestBody : ""));
                break;
            case "PUT":
                requestBuilder.PUT(HttpRequest.BodyPublishers.ofString(
                        requestBody != null ? requestBody : ""));
                break;
            case "DELETE":
                requestBuilder.DELETE();
                break;
        }

        HttpRequest request = requestBuilder.build();
        HttpResponse<String> response = null;
        try {
            response = client.send(request,
                    HttpResponse.BodyHandlers.ofString());
        } catch (IOException | InterruptedException e) {
            throw new Error(e);
        }

        // Handle response as needed
        System.out.println("Status: " + response.statusCode());
        System.out.println("Body: " + response.body());
    }
}

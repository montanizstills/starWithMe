package http;

import io.github.montanizstills.heygenAPI.HeygenUtils;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public enum SimpleHttp {
    GET, POST, PUT, DELETE;

    public void sendRequest(String uriInput, String requestBody)
            throws IOException, InterruptedException {

        HeygenUtils heygenUtils = new HeygenUtils();
        heygenUtils.createAPIKey();

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder()
                .uri(URI.create(uriInput))
                .header("Content-Type", "application/json")
                .header("x-api-key", heygenUtils.getHeygen_api_key());

        // Set the HTTP method and body if applicable
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
        System.out.println(requestBody);
        HttpResponse<String> response = client.send(request,
                HttpResponse.BodyHandlers.ofString());

        // Handle response as needed
        System.out.println("Status: " + response.statusCode());
        System.out.println("Body: " + response.body());
    }
}

// Usage examples:
//sendRequest("https://api.example.com/resource",HttpMethod.GET, null);
//sendRequest("https://api.example.com/resource",HttpMethod.POST, "{\"key\":\"value\"}");
//sendRequest("https://api.example.com/resource/1",HttpMethod.PUT, "{\"key\":\"updated\"}");
//sendRequest("https://api.example.com/resource/1",HttpMethod.DELETE, null);

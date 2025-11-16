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

    public String getHeygen_api_key(){
        return this.heygen_api_key;
    }

    public void createAPIKey() {
        try {
            this.heygen_api_key = new Utils().createJsonMap("secrets.json").get("HEYGEN_API_KEY");
        } catch (JsonProcessingException e) {
            throw new Error(e);
        }
    }

}

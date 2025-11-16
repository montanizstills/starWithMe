package io.github.montanizstills.heygenAPI;


public class HeygenUtils {

    private final String heygen_api_key;

    public HeygenUtils() {
        this.heygen_api_key = System.getenv().get("HEYGEN_API_KEY");
    }

    public String getHeygen_api_key() {
        return this.heygen_api_key;
    }

}

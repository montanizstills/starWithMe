package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.BackgroundSettings;

// ==================== Image Background ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class ImageBackground implements BackgroundSettings {
    @JsonProperty("type")
    private String type = "image";

    @JsonProperty("url")
    private String url;

    @JsonProperty("image_asset_id")
    private String imageAssetId;

    @JsonProperty("fit")
    private String fit = "cover";

    public ImageBackground() {
    }

    public ImageBackground(String url, String imageAssetId) {
        this.url = url;
        this.imageAssetId = imageAssetId;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public String getImageAssetId() {
        return imageAssetId;
    }

    public void setImageAssetId(String imageAssetId) {
        this.imageAssetId = imageAssetId;
    }

    public String getFit() {
        return fit;
    }

    public void setFit(String fit) {
        this.fit = fit;
    }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.BackgroundSettings;

// ==================== Video Background ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class VideoBackground implements BackgroundSettings {
    @JsonProperty("type")
    private String type = "video";

    @JsonProperty("url")
    private String url;

    @JsonProperty("video_asset_id")
    private String videoAssetId;

    @JsonProperty("play_style")
    private String playStyle;

    @JsonProperty("fit")
    private String fit = "cover";

    public VideoBackground() {
    }

    public VideoBackground(String url, String videoAssetId, String playStyle) {
        this.url = url;
        this.videoAssetId = videoAssetId;
        this.playStyle = playStyle;
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

    public String getVideoAssetId() {
        return videoAssetId;
    }

    public void setVideoAssetId(String videoAssetId) {
        this.videoAssetId = videoAssetId;
    }

    public String getPlayStyle() {
        return playStyle;
    }

    public void setPlayStyle(String playStyle) {
        this.playStyle = playStyle;
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

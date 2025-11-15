package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.VideoInput;

import java.util.List;

// ==================== Main Request Class ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class CreateAvatarVideoRequest {
    @JsonProperty("caption")
    private Boolean caption;

    @JsonProperty("title")
    private String title;

    @JsonProperty("callback_id")
    private String callbackId;

    @JsonProperty("video_inputs")
    private List<VideoInput> videoInputs;

    @JsonProperty("dimension")
    private Dimension dimension;

    @JsonProperty("folder_id")
    private String folderId;

    @JsonProperty("callback_url")
    private String callbackUrl;

    // Constructors
    public CreateAvatarVideoRequest() {
    }

    public CreateAvatarVideoRequest(List<VideoInput> videoInputs, Dimension dimension) {
        this.videoInputs = videoInputs;
        this.dimension = dimension;
    }

    // Getters and Setters
    public Boolean getCaption() {
        return caption;
    }

    public void setCaption(Boolean caption) {
        this.caption = caption;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getCallbackId() {
        return callbackId;
    }

    public void setCallbackId(String callbackId) {
        this.callbackId = callbackId;
    }

    public List<VideoInput> getVideoInputs() {
        return videoInputs;
    }

    public void setVideoInputs(List<VideoInput> videoInputs) {
        this.videoInputs = videoInputs;
    }

    public Dimension getDimension() {
        return dimension;
    }

    public void setDimension(Dimension dimension) {
        this.dimension = dimension;
    }

    public String getFolderId() {
        return folderId;
    }

    public void setFolderId(String folderId) {
        this.folderId = folderId;
    }

    public String getCallbackUrl() {
        return callbackUrl;
    }

    public void setCallbackUrl(String callbackUrl) {
        this.callbackUrl = callbackUrl;
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

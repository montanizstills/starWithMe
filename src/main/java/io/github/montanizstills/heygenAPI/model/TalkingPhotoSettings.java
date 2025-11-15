package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.CharacterSettings;

// ==================== Talking Photo Settings ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class TalkingPhotoSettings implements CharacterSettings {
    @JsonProperty("type")
    private String type = "talking_photo";

    @JsonProperty("talking_photo_id")
    private String talkingPhotoId;

    @JsonProperty("scale")
    private Float scale = 1.0f;

    @JsonProperty("talking_photo_style")
    private String talkingPhotoStyle;

    @JsonProperty("offset")
    private Offset offset;

    @JsonProperty("talking_style")
    private String talkingStyle;

    @JsonProperty("expression")
    private String expression;

    @JsonProperty("super_resolution")
    private Boolean superResolution;

    @JsonProperty("matting")
    private Boolean matting;

    @JsonProperty("circle_background_color")
    private String circleBackgroundColor;

    // Constructors
    public TalkingPhotoSettings() {
    }

    public TalkingPhotoSettings(String talkingPhotoId) {
        this.talkingPhotoId = talkingPhotoId;
    }

    // Getters and Setters
    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getTalkingPhotoId() {
        return talkingPhotoId;
    }

    public void setTalkingPhotoId(String talkingPhotoId) {
        this.talkingPhotoId = talkingPhotoId;
    }

    public Float getScale() {
        return scale;
    }

    public void setScale(Float scale) {
        this.scale = scale;
    }

    public String getTalkingPhotoStyle() {
        return talkingPhotoStyle;
    }

    public void setTalkingPhotoStyle(String talkingPhotoStyle) {
        this.talkingPhotoStyle = talkingPhotoStyle;
    }

    public Offset getOffset() {
        return offset;
    }

    public void setOffset(Offset offset) {
        this.offset = offset;
    }

    public String getTalkingStyle() {
        return talkingStyle;
    }

    public void setTalkingStyle(String talkingStyle) {
        this.talkingStyle = talkingStyle;
    }

    public String getExpression() {
        return expression;
    }

    public void setExpression(String expression) {
        this.expression = expression;
    }

    public Boolean getSuperResolution() {
        return superResolution;
    }

    public void setSuperResolution(Boolean superResolution) {
        this.superResolution = superResolution;
    }

    public Boolean getMatting() {
        return matting;
    }

    public void setMatting(Boolean matting) {
        this.matting = matting;
    }

    public String getCircleBackgroundColor() {
        return circleBackgroundColor;
    }

    public void setCircleBackgroundColor(String circleBackgroundColor) {
        this.circleBackgroundColor = circleBackgroundColor;
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

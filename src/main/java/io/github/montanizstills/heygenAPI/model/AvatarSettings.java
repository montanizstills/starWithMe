package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.CharacterSettings;

// ==================== Avatar Settings ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class AvatarSettings implements CharacterSettings {
    @JsonProperty("type")
    private String type = "avatar";

    @JsonProperty("avatar_id")
    private String avatarId;

    @JsonProperty("scale")
    private Float scale = 1.0f;

    @JsonProperty("avatar_style")
    private String avatarStyle;

    @JsonProperty("offset")
    private Offset offset;

    @JsonProperty("matting")
    private Boolean matting;

    @JsonProperty("circle_background_color")
    private String circleBackgroundColor;

    // Constructors
    public AvatarSettings() {
    }

    public AvatarSettings(String avatarId) {
        this.avatarId = avatarId;
    }

    // Getters and Setters
    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getAvatarId() {
        return avatarId;
    }

    public void setAvatarId(String avatarId) {
        this.avatarId = avatarId;
    }

    public Float getScale() {
        return scale;
    }

    public void setScale(Float scale) {
        this.scale = scale;
    }

    public String getAvatarStyle() {
        return avatarStyle;
    }

    public void setAvatarStyle(String avatarStyle) {
        this.avatarStyle = avatarStyle;
    }

    public Offset getOffset() {
        return offset;
    }

    public void setOffset(Offset offset) {
        this.offset = offset;
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

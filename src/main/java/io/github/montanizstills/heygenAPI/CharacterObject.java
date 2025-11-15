package io.github.montanizstills.heygenAPI;

import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.model.Offset;

public class CharacterObject {
    @JsonProperty(required = true, defaultValue = "avatar")
    private String type;

    @JsonProperty(required = true)
    private String avatarId;

    @JsonProperty(required = true)
    private String talkingPhotoId;

    @JsonProperty(defaultValue = "1")
    private Double scale;

    @JsonProperty(defaultValue = "normal")
    private String avatarStyle;

    private String talkingPhotoStyle;

    private Offset offset;

    @JsonProperty(defaultValue = "stable")
    private String talkingStyle;

    private String expression;

    private String superResolution;

    private String matting;

    private String circleBackgroundColor;
}

package io.github.montanizstills.heygenAPI.model.character;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.interfaces.ICharacterSettings;
import io.github.montanizstills.heygenAPI.utils.Offset;
import lombok.*;

import java.io.Serializable;


@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CharacterSettings implements ICharacterSettings, Serializable {
    @JsonProperty(value = "type", required = true, defaultValue = "avatar")
    private String type;

    @JsonProperty(required = true)
    private String avatarId;


    @JsonProperty(value = "talking_photo_id", required = true)
    private String talkingPhotoId;

    @JsonProperty(value = "scale", defaultValue = "1")
    private Float scale;

    @JsonProperty(value = "avatar_style", defaultValue = "normal")
    private String avatarStyle;

    @JsonProperty(value = "talking_photo_style")
    private String talkingPhotoStyle;

    @JsonProperty(value = "offset")
    private Offset offset;

    @JsonProperty(value = "talking_style", defaultValue = "stable")
    private String talkingStyle;

    @JsonProperty(value = "expression")
    private String expression;

    @JsonProperty(value = "super_resolution")
    private Boolean superResolution;

    @JsonProperty(value = "matting")
    private Boolean matting;

    @JsonProperty(value = "circle_background_color")
    private String circleBackgroundColor;
}


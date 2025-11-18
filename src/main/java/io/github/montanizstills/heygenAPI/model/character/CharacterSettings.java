package io.github.montanizstills.heygenAPI.model.character;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.model.Offset;
import lombok.*;

import java.io.Serializable;


@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CharacterSettings implements ICharacterSettings {
    @Builder.Default
    @JsonProperty(value = "type", required = true)
    private String type = "avatar";

    @JsonProperty(value = "avatar_id", required = true)
    private String avatarId;

    @JsonProperty(value = "talking_photo_id", required = true)
    private String talkingPhotoId;

    @JsonProperty(value = "scale", defaultValue = "1")
    private Float scale; // todo - valid ranges between 0-5

    @JsonProperty(value = "avatar_style", defaultValue = "normal")
    // todo - JsonProperty default value might be an issue with ENUM(s)
    private AvatarStyle avatarStyle;

    @JsonProperty(value = "talking_photo_style")
    private TalkingPhotoStyle talkingPhotoStyle;

    @JsonProperty(value = "offset")
    private Offset offset;

    @JsonProperty(value = "talking_style", defaultValue = "stable")
    private TalkingStyle talkingStyle;

    @JsonProperty(value = "expression")
    private Expression expression;

    @JsonProperty(value = "super_resolution")
    private Boolean superResolution; // todo - Applies only to the talking_photo type.

    @JsonProperty(value = "matting")
    private Boolean matting; // todo - Applies to both avatar and talking_photo type.

    @JsonProperty(value = "circle_background_color")
    private String circleBackgroundColor; // todo -  Must be specified in hex format (e.g., #FFFFFF). Applies to both avatar and talking_photo type.
}


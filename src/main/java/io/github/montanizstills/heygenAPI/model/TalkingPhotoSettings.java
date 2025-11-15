package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.CharacterSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
class TalkingPhotoSettings implements CharacterSettings {
    @JsonProperty("type")
    private String type = "talking_photo";

    @JsonProperty("talking_photo_id")
    private String talkingPhotoId;

    @JsonProperty("scale") //todo - add default value
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

}

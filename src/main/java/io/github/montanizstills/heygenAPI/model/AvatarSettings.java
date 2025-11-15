package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.CharacterSettings;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AvatarSettings implements CharacterSettings {
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

}

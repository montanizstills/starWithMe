package io.github.montanizstills.heygenAPI.model.text;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.utils.Position;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Text {
    @JsonProperty(value = "type", required = true)
    private String type;

    @JsonProperty(value = "text", required = true)
    private String text;

    @JsonProperty(value="font_family")
    private String fontFamily;

    @JsonProperty(value="font_size")
    private String fontSize;

    @JsonProperty(value="font_weight")
    private String fontWeight;

    @JsonProperty(value="color")
    private String color;

    @JsonProperty(value="position")
    private Position position;

    private String textAlign;

    @JsonProperty(required = true)
    private String lineHeight;

}

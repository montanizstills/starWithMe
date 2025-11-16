package io.github.montanizstills.heygenAPI.model.text;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.model.Position;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Text {
    @Builder.Default
    @JsonProperty(value = "type", required = true)
    private final String type = "text";

    @JsonProperty(value = "text", required = true)
    private String text;

    @JsonProperty(value="font_family")
    private String fontFamily;

    @JsonProperty(value="font_size")
    private Float fontSize;

    @JsonProperty(value="font_weight")
    private String fontWeight;

    @JsonProperty(value="color")
    private String color; // todo - Text color in hex format (e.g., #FFFFFF).

    @JsonProperty(value="position")
    private Position position;

    private TextAlign textAlign;

    @JsonProperty(required = true)
    private String lineHeight;

}

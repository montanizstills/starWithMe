package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Dimension {
    @JsonProperty(value = "width", defaultValue = "1280")
    private Integer width;

    @JsonProperty(value = "height", defaultValue = "720")
    private Integer height;
}

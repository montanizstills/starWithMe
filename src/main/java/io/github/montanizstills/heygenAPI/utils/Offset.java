package io.github.montanizstills.heygenAPI.utils;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Offset {
    @JsonProperty("x")
    private Float x;

    @JsonProperty("y")
    private Float y;

} // todo - Applies to both avatar and talking_photo type.

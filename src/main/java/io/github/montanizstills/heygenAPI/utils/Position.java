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
public class Position {

    @JsonProperty(value = "x", required = true)
    private double x;

    @JsonProperty(value = "y", required = true)
    private double y;
}

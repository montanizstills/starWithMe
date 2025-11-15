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
public class ElevenLabsSettings {
    @JsonProperty("model")
    private String model;

    @JsonProperty("similarity_boost")
    private Float similarityBoost;

    @JsonProperty("stability")
    private Float stability;

    @JsonProperty("style")
    private Float style;

}

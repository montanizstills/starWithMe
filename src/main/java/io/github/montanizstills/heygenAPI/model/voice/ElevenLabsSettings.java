package io.github.montanizstills.heygenAPI.model.voice;

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
    private ElevenLabsModel model;

    @JsonProperty("similarity_boost")
    private Float similarityBoost; // todo - Value ranges from 0.0 to 1.0.

    @JsonProperty("stability")
    private Float stability; // todo - Value ranges from 0.0 to 1.0.

    @JsonProperty("style")
    private Float style; // todo - Value ranges from 0.0 to 1.0.

}

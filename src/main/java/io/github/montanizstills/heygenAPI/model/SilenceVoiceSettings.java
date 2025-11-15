package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class SilenceVoiceSettings implements VoiceSettings {
    @JsonProperty("type")
    private String type = "silence";

    @JsonProperty("duration")
    private Float duration = 1.0f;

}

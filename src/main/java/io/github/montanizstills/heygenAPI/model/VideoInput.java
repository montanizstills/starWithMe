package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import io.github.montanizstills.heygenAPI.interfaces.IBackgroundSettings;
import io.github.montanizstills.heygenAPI.interfaces.ICharacterSettings;
import io.github.montanizstills.heygenAPI.interfaces.IVoiceSettings;
import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class VideoInput {
    @JsonProperty("character")
    private ICharacterSettings character;
    
    @JsonProperty("voice")
    private IVoiceSettings voice;
    
    @JsonProperty("background")
    private IBackgroundSettings background;
}

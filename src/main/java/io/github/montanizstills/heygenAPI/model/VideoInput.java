package io.github.montanizstills.heygenAPI.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.montanizstills.heygenAPI.model.interfaces.BackgroundSettings;
import io.github.montanizstills.heygenAPI.model.interfaces.CharacterSettings;
import io.github.montanizstills.heygenAPI.model.interfaces.VoiceSettings;

// ==================== Video Input ====================
@JsonInclude(JsonInclude.Include.NON_NULL)
class VideoInput {
    @JsonProperty("character")
    private CharacterSettings character;

    @JsonProperty("voice")
    private VoiceSettings voice;

    @JsonProperty("background")
    private BackgroundSettings background;

    // Constructors
    public VideoInput() {
    }

    public VideoInput(VoiceSettings voice) {
        this.voice = voice;
    }

    public VideoInput(CharacterSettings character, VoiceSettings voice, BackgroundSettings background) {
        this.character = character;
        this.voice = voice;
        this.background = background;
    }

    // Getters and Setters
    public CharacterSettings getCharacter() {
        return character;
    }

    public void setCharacter(CharacterSettings character) {
        this.character = character;
    }

    public VoiceSettings getVoice() {
        return voice;
    }

    public void setVoice(VoiceSettings voice) {
        this.voice = voice;
    }

    public BackgroundSettings getBackground() {
        return background;
    }

    public void setBackground(BackgroundSettings background) {
        this.background = background;
    }

    @Override
    public String toString() {
        try {
            ObjectMapper mapper = new ObjectMapper();
            return mapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            return "Error converting to JSON: " + e.getMessage();
        }
    }
}

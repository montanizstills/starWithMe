package io.github.montanizstills.heygenAPI.model.voice;

public enum VoiceType {
    Text, Audio, Silence;

    private String voiceType;

    VoiceType() {
        this.voiceType = this.name().toLowerCase();
    }
}

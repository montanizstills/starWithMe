package io.github.montanizstills.heygenAPI.model.voice;

import io.github.montanizstills.heygenAPI.utils.JsonEnum;

public enum VoiceType implements JsonEnum {
    Text, Audio, Silence;

    private String voiceType;

    VoiceType() {
        this.voiceType = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.voiceType;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

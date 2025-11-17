package io.github.montanizstills.heygenAPI.model.voice;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum Emotion implements JsonEnum {
    Excited, Friendly, Serious, Soothing, Broadcaster;

    private String emotion;

    Emotion(){
        this.emotion = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.emotion;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

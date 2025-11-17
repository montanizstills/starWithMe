package io.github.montanizstills.heygenAPI.model.voice;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum ElevenLabsModel implements JsonEnum {
    eleven_monolingual_v1,
    eleven_multilingual_v1,
    eleven_multilingual_v2,
    eleven_turbo_v2,
    eleven_turbo_v2_5;

    private String elevenLabsModel;

    ElevenLabsModel(){
        this.elevenLabsModel = this.name();
    }

    @Override
    public String getValue() {
        return this.elevenLabsModel;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

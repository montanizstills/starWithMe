package io.github.montanizstills.heygenAPI.model.voice;

public enum ElevenLabsModel {
    eleven_monolingual_v1,
    eleven_multilingual_v1,
    eleven_multilingual_v2,
    eleven_turbo_v2,
    eleven_turbo_v2_5;

    private String elevenLabsModel;

    ElevenLabsModel(){
        this.elevenLabsModel = this.name();
    }
}

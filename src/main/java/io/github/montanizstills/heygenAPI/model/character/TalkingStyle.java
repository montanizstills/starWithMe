package io.github.montanizstills.heygenAPI.model.character;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum TalkingStyle implements JsonEnum {
    Stable, Expressive;

    private final String talkingStyle;

    TalkingStyle() {
        this.talkingStyle = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.talkingStyle;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

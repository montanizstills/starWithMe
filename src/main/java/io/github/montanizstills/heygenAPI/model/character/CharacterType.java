package io.github.montanizstills.heygenAPI.model.character;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum CharacterType implements JsonEnum {
    AVATAR, TALKING_PHOTO;

    private final String type;

    CharacterType() {
        this.type = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.type;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

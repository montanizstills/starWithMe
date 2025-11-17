package io.github.montanizstills.heygenAPI.model.character;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum AvatarStyle implements JsonEnum {
    Circle, CloseUp, Normal;

    private final String style;

    AvatarStyle() {
        this.style = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.style;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

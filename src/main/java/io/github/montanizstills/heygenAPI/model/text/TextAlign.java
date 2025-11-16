package io.github.montanizstills.heygenAPI.model.text;

import io.github.montanizstills.heygenAPI.utils.JsonEnum;

public enum TextAlign implements JsonEnum {
    LEFT,
    CENTER,
    RIGHT;

    private String textAlign;

    TextAlign() {
        this.textAlign = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.textAlign;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

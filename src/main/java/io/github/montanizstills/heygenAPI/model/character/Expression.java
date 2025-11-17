package io.github.montanizstills.heygenAPI.model.character;

import io.github.montanizstills.heygenAPI.json.JsonEnum;

public enum Expression implements JsonEnum {
    Default, Happy;

    private String expression;

    Expression() {
        this.expression = this.name().toLowerCase();
    } // todo - Applies only to the talking_photo type.

    @Override
    public String getValue() {
        return this.expression;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

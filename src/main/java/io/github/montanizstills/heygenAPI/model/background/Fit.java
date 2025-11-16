package io.github.montanizstills.heygenAPI.model.background;

import io.github.montanizstills.heygenAPI.utils.JsonEnum;

public enum Fit implements JsonEnum {
    Crop, Cover, Contain, None;
    private String fit;

    Fit() {
        this.fit = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.fit;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

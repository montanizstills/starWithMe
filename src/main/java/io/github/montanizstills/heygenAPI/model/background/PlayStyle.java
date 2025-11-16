package io.github.montanizstills.heygenAPI.model.background;

import io.github.montanizstills.heygenAPI.utils.JsonEnum;

public enum PlayStyle implements JsonEnum {
    Freeze, Loop, Fit_To_Scene, Once;
    private String playStyle;

    PlayStyle() {
        this.playStyle = this.name().toLowerCase();
    }

    @Override
    public String getValue() {
        return this.playStyle;
    }

    @Override
    public String toJson() {
        return JsonEnum.super.toJson();
    }
}

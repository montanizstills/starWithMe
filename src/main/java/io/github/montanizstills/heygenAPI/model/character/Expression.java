package io.github.montanizstills.heygenAPI.model.character;

public enum Expression {
    Default, Happy;

    private String expression;

    Expression() {
        this.expression = this.name().toLowerCase();
    } // todo - Applies only to the talking_photo type.
}

package io.github.montanizstills.heygenAPI.model.photo;

import io.github.montanizstills.heygenAPI.json.JsonEnum;
import lombok.AllArgsConstructor;

@AllArgsConstructor
public enum Age implements JsonEnum {
    Young_Adult("Young Adult"),
    Early_Middle_Age("Early Middle Age"),
    Late_Middle_Age("Late Middle Age"),
    Senior,
    Unspecified;

    private final String age;

    Age() {
        this.age = name(); // uses title-case capitalization, has space seperated vales
    }

    @Override
    public String getValue() {
        return this.age;
    }

}

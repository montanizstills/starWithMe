package io.github.montanizstills.heygenAPI.utils;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.BeanProperty;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.deser.ContextualDeserializer;

import java.io.IOException;

/**
 * Generic deserializer for JsonEnum implementations.
 * This deserializer can handle any enum that implements JsonEnum.
 */
public class JsonEnumDeserializer extends JsonDeserializer<JsonEnum> implements ContextualDeserializer {

    private Class<?> enumClass;

    public JsonEnumDeserializer() {
        // No-arg constructor required by Jackson
    }

    private JsonEnumDeserializer(Class<?> enumClass) {
        this.enumClass = enumClass;
    }

    @Override
    public JsonDeserializer<?> createContextual(DeserializationContext ctxt, BeanProperty property)
            throws JsonMappingException {
        Class<?> rawClass = property.getType().getRawClass();
        if (JsonEnum.class.isAssignableFrom(rawClass) && rawClass.isEnum()) {
            return new JsonEnumDeserializer(rawClass);
        }
        return this;
    }

    @Override
    public JsonEnum deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String value = p.getValueAsString();
        if (value == null) {
            return null;
        }

        try {
            return JsonEnum.fromValue(enumClass, value);
        } catch (IllegalArgumentException e) {
            throw JsonMappingException.from(p, e.getMessage(), e);
        }
    }
}
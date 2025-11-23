package io.github.montanizstills.http;

import lombok.AllArgsConstructor;
import lombok.Data;

@AllArgsConstructor
@Data
public class SimpleHttpResponse {
    private String body;
    private int statusCode;
}

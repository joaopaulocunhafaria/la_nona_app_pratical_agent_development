package com.lanona.api.exception;

import org.springframework.http.HttpStatus;

/**
 * Base para excecoes de negocio que o GlobalExceptionHandler traduz
 * diretamente para uma resposta HTTP com o status correspondente.
 */
public abstract class ApiException extends RuntimeException {

    private final HttpStatus status;

    protected ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}

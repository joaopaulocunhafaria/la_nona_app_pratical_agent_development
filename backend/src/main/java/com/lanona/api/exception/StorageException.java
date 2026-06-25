package com.lanona.api.exception;

import org.springframework.http.HttpStatus;

/**
 * Falha ao enviar/remover um arquivo do bucket (Amazon S3). Traduzida pelo
 * GlobalExceptionHandler para um 500 com mensagem amigavel, sem vazar detalhes
 * internos do SDK ao cliente.
 */
public class StorageException extends ApiException {

    public StorageException(String message) {
        super(HttpStatus.INTERNAL_SERVER_ERROR, message);
    }
}

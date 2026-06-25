package com.lanona.api.config;

import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Cria o cliente {@link AmazonS3} como bean singleton gerenciado pelo Spring,
 * injetavel em {@code S3StorageService}. Nenhuma outra classe deve instanciar o
 * cliente diretamente.
 *
 * <p>As credenciais vem da config ({@code amazon.accessKey}/{@code amazon.secretKey}).
 * Quando ambas estao vazias — caso tipico em ambientes AWS (EC2/ECS/EKS) — o
 * cliente cai no {@link DefaultAWSCredentialsProviderChain}, que resolve as
 * credenciais automaticamente via IAM Role, evitando chaves estaticas no codigo.
 */
@Configuration
public class AwsConfig {

    @Value("${amazon.region}")
    private String region;

    @Value("${amazon.accessKey:}")
    private String accessKey;

    @Value("${amazon.secretKey:}")
    private String secretKey;

    @Bean
    AmazonS3 amazonS3() {
        AmazonS3ClientBuilder builder = AmazonS3ClientBuilder.standard()
                .withRegion(region);

        if (accessKey != null && !accessKey.isBlank() && secretKey != null && !secretKey.isBlank()) {
            builder.withCredentials(new AWSStaticCredentialsProvider(
                    new BasicAWSCredentials(accessKey, secretKey)));
        } else {
            builder.withCredentials(new DefaultAWSCredentialsProviderChain());
        }

        return builder.build();
    }
}

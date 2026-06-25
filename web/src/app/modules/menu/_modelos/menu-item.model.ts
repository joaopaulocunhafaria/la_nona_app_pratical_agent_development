export interface MenuItemImage {
	id: string;
	/** URL pública da imagem no bucket (ou data URI legada de itens antigos). */
	url: string;
	position: number;
}

export interface MenuItem {
	id: string;
	name: string;
	description: string;
	price: number;
	category: string;
	available: boolean;
	images: MenuItemImage[];
	createdAt: string;
	updatedAt: string;
}

/**
 * Imagem enviada ao backend. Para uma imagem nova, informe `base64` +
 * `contentType` (o backend faz o upload ao bucket). Para manter uma imagem já
 * existente na edição, informe apenas `url`.
 */
export interface MenuItemImageRequest {
	url?: string;
	base64?: string;
	contentType?: string;
}

export interface MenuItemRequest {
	name: string;
	description: string;
	price: number;
	category: string;
	available: boolean;
	images: MenuItemImageRequest[];
}

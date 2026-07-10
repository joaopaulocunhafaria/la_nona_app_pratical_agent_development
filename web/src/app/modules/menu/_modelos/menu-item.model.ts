export interface MenuItemImage {
	id: string;
	/** URL pública da imagem no bucket (ou data URI legada de itens antigos). */
	url: string;
	position: number;
}

/** Situação de um item do cardápio (espelha o enum MenuItemStatus do backend). */
export type MenuItemStatus = 'DISPONIVEL' | 'FEITO_NA_HORA' | 'VERIFICAR_DISPONIBILIDADE' | 'INDISPONIVEL';

/** Rótulo exibido ao usuário para cada status. */
export const STATUS_LABELS: Record<MenuItemStatus, string> = {
	DISPONIVEL: 'Disponível',
	FEITO_NA_HORA: 'Feito na hora',
	VERIFICAR_DISPONIBILIDADE: 'Verificar disponibilidade',
	INDISPONIVEL: 'Indisponível',
};

/** Severidade (cor) do p-tag para cada status. */
export const STATUS_SEVERITIES: Record<MenuItemStatus, 'success' | 'info' | 'warn' | 'danger'> = {
	DISPONIVEL: 'success',
	FEITO_NA_HORA: 'info',
	VERIFICAR_DISPONIBILIDADE: 'warn',
	INDISPONIVEL: 'danger',
};

/** Opções de status para selects (cadastro de itens). */
export const STATUS_OPTIONS: { label: string; value: MenuItemStatus }[] = (Object.keys(STATUS_LABELS) as MenuItemStatus[]).map(
	(value) => ({ label: STATUS_LABELS[value], value }),
);

/** Indica se o item pode ser adicionado ao carrinho no status informado. */
export function podePedir(status: MenuItemStatus): boolean {
	return status !== 'INDISPONIVEL';
}

export interface MenuItem {
	id: string;
	name: string;
	description: string;
	price: number;
	/** Nome da categoria (para exibição e filtro no cardápio). */
	category: string;
	/** Id da categoria vinculada (usado no formulário de edição). */
	categoryId: string;
	status: MenuItemStatus;
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
	/** Id da categoria selecionada (o backend também aceita o nome). */
	category: string;
	status: MenuItemStatus;
	images: MenuItemImageRequest[];
}
